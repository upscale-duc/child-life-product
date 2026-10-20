import {
  keepsakeBrandSize,
  keepsakeBrandSvg,
  type KeepsakeVideoBrand,
  type KeepsakePresentation,
} from '@child-life/contracts';
import type { CSSProperties, ReactNode } from 'react';
import {
  AbsoluteFill,
  Audio,
  Easing,
  Img,
  Sequence,
  interpolate,
  random,
  spring,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
} from 'remotion';

/**
 * The scene kit of the Chapter 01 videos (docs/product/remember-2-templates.md §4.3): timing,
 * transitions, photo scenes, type, particles, the logo and the music. Compositions only arrange
 * these; everything is drawn from the props (photos, texts, palette) and the original art library
 * (`public/art`, synced from design/keepsake-art).
 */

export const FPS = 30;
export const W = 1080;
export const H = 1920;
export const sec = (s: number) => Math.round(s * FPS);

/** What a Chapter 01 composition receives (a superset of the V1 props). */
export interface StoryProps {
  presentation?: KeepsakePresentation;
  artAssets?: Record<string, string>;
  photos: string[];
  title: string;
  message: string;
  name: string;
  dateLine: string;
  mark: string | null;
  palette: { background: string; ink: string; accent: string };
  music: string | null;
  durationSec: number;
  brand?: KeepsakeVideoBrand | null;
  headline?: string;
  closing?: string;
  lines?: string;
  letter?: string;
  photoInfo?: { takenAt: string | null; label: string | null }[];
  locale?: 'vi' | 'en';
  birthStats?: string | null;
  [key: string]: unknown;
}

// ---------- Type ----------

const faces: [string, string, number, string][] = [
  ['BVP', 'BeVietnamPro-Regular', 400, 'normal'],
  ['BVP', 'BeVietnamPro-SemiBold', 600, 'normal'],
  ['BVP', 'BeVietnamPro-Bold', 700, 'normal'],
  ['Lora', 'Lora-Regular', 400, 'normal'],
  ['Lora', 'Lora-Italic', 400, 'italic'],
  ['Lora', 'Lora-SemiBold', 600, 'normal'],
  ['Lora', 'Lora-SemiBoldItalic', 600, 'italic'],
  ['Dancing', 'DancingScript-Regular', 400, 'normal'],
  ['Dancing', 'DancingScript-SemiBold', 600, 'normal'],
  ['Playfair', 'PlayfairDisplay-Regular', 400, 'normal'],
  ['Playfair', 'PlayfairDisplay-Italic', 400, 'italic'],
  ['Playfair', 'PlayfairDisplay-Bold', 700, 'normal'],
  ['Baloo', 'Baloo2-Medium', 500, 'normal'],
  ['Baloo', 'Baloo2-Bold', 700, 'normal'],
  ['Baloo', 'Baloo2-ExtraBold', 800, 'normal'],
  ['Patrick', 'PatrickHand-Regular', 400, 'normal'],
];
export function Fonts() {
  const css = faces
    .map(
      ([family, file, weight, style]) =>
        `@font-face{font-family:'${family}';font-weight:${weight};font-style:${style};src:url('${staticFile(`fonts/${file}.ttf`)}')}`,
    )
    .join('\n');
  return <style>{css}</style>;
}
export const font = {
  sans: "BVP, 'Be Vietnam Pro', sans-serif",
  serif: "Lora, 'Lora', Georgia, serif",
  script: "Dancing, 'Dancing Script', cursive",
  display: "Playfair, 'Playfair Display', Georgia, serif",
  round: "Baloo, 'Baloo 2', sans-serif",
  hand: "Patrick, 'Patrick Hand', cursive",
};

export const art = (name: string) => staticFile(`art/${name}.svg`);

// ---------- Timeline ----------

export type Transition =
  'fade' | 'slideLeft' | 'slideUp' | 'zoom' | 'iris' | 'wipe' | 'pop' | 'cut';

export interface Scene {
  len: number;
  /** Frames shared with the next scene (its entrance runs over this one's exit). */
  overlap?: number;
  enter?: Transition;
  exit?: Transition;
  render: (len: number) => ReactNode;
}

/** Start frame of each scene and the total length. */
export function layout(scenes: Scene[]): { starts: number[]; total: number } {
  const starts: number[] = [];
  let at = 0;
  scenes.forEach((s, i) => {
    starts.push(at);
    at += s.len - (i < scenes.length - 1 ? (s.overlap ?? 0) : 0);
  });
  return { starts, total: at };
}

/** Per-photo time that keeps the video inside its range (§4.2). */
export function perPhoto(
  totalSec: number,
  fixedSec: number,
  photos: number,
  minSec: number,
  maxSec: number,
): number {
  const n = Math.max(1, photos);
  // On screen between min and max, plus the half second shared with the next scene.
  return sec(Math.min(maxSec, Math.max(minSec, (totalSec - fixedSec) / n)) + 0.5);
}

function transitionStyle(t: Transition | undefined, p: number, entering: boolean): CSSProperties {
  // p: 0 → 1 over the transition (entering: appearing; else: disappearing).
  const e = Easing.inOut(Easing.cubic)(p);
  switch (t) {
    case 'cut':
    case undefined:
      return {};
    case 'fade':
      return { opacity: entering ? e : 1 - e };
    case 'slideLeft':
      return entering
        ? { transform: `translateX(${(1 - e) * 100}%)` }
        : { transform: `translateX(${-e * 30}%)`, opacity: 1 - e };
    case 'slideUp':
      return entering
        ? { transform: `translateY(${(1 - e) * 100}%)` }
        : { transform: `translateY(${-e * 20}%)`, opacity: 1 - e };
    case 'zoom':
      return entering
        ? { transform: `scale(${0.92 + 0.08 * e})`, opacity: e }
        : { transform: `scale(${1 + 0.25 * e})`, opacity: 1 - e };
    case 'iris':
      return entering ? { clipPath: `circle(${e * 80}% at 50% 50%)` } : { opacity: 1 - e };
    case 'wipe':
      return entering ? { clipPath: `inset(0 ${(1 - e) * 100}% 0 0)` } : {};
    case 'pop': {
      const s = entering ? 0.8 + 0.25 * Math.sin((e * Math.PI) / 1.2) : 1;
      return entering
        ? { transform: `scale(${s})`, opacity: Math.min(1, e * 2) }
        : { opacity: 1 - e };
    }
  }
}

/** Plays [scenes] back to back with their overlaps and transitions. */
export function Timeline({ scenes }: { scenes: Scene[] }) {
  const { starts } = layout(scenes);
  return (
    <>
      {scenes.map((s, i) => (
        <Sequence key={i} from={starts[i]!} durationInFrames={s.len}>
          <Transitioned
            len={s.len}
            enterFrames={i > 0 ? (scenes[i - 1]!.overlap ?? 0) : 0}
            exitFrames={i < scenes.length - 1 ? (s.overlap ?? 0) : 0}
            enter={s.enter}
            exit={s.exit}
          >
            {s.render(s.len)}
          </Transitioned>
        </Sequence>
      ))}
    </>
  );
}

function Transitioned({
  len,
  enterFrames,
  exitFrames,
  enter,
  exit,
  children,
}: {
  len: number;
  enterFrames: number;
  exitFrames: number;
  enter?: Transition | undefined;
  exit?: Transition | undefined;
  children: ReactNode;
}) {
  const f = useCurrentFrame();
  let style: CSSProperties = {};
  if (enterFrames > 0 && f < enterFrames)
    style = transitionStyle(enter ?? 'fade', f / enterFrames, true);
  else if (exitFrames > 0 && f > len - exitFrames) {
    style = transitionStyle(exit ?? 'fade', (f - (len - exitFrames)) / exitFrames, false);
  }
  return <AbsoluteFill style={style}>{children}</AbsoluteFill>;
}

// ---------- Motion helpers ----------

export const clamp = { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' } as const;
export function useSpring(delay = 0, damping = 14) {
  const f = useCurrentFrame();
  const { fps } = useVideoConfig();
  return spring({ frame: f - delay, fps, config: { damping, mass: 0.8 } });
}

// ---------- Photo scenes ----------

/** Full-bleed photo with a slow zoom and drift (Ken Burns). */
export function PhotoFill({
  src,
  len,
  from = 1,
  to = 1.1,
  drift = 30,
  grain = false,
}: {
  src: string;
  len: number;
  from?: number;
  to?: number;
  drift?: number;
  grain?: boolean;
}) {
  const f = useCurrentFrame();
  const z = interpolate(f, [0, len], [from, to], { easing: Easing.inOut(Easing.ease) });
  const x = interpolate(f, [0, len], [0, drift]);
  return (
    <AbsoluteFill style={{ backgroundColor: '#000', overflow: 'hidden' }}>
      <Img
        src={src}
        style={{
          width: '100%',
          height: '100%',
          objectFit: 'cover',
          objectPosition: '50% 40%',
          transform: `scale(${z}) translateX(${x}px)`,
        }}
      />
      {grain && (
        <Img
          src={art('paper-grain')}
          style={{
            position: 'absolute',
            inset: 0,
            width: '100%',
            height: '100%',
            opacity: 0.5,
            mixBlendMode: 'multiply',
          }}
        />
      )}
    </AbsoluteFill>
  );
}

/** The whole photo, over a blurred copy of itself (landscape-safe). */
export function PhotoBlurFill({
  src,
  len,
  radius = 0,
  style,
}: {
  src: string;
  len: number;
  radius?: number;
  style?: CSSProperties;
}) {
  const f = useCurrentFrame();
  const z = interpolate(f, [0, len], [1, 1.05]);
  return (
    <div
      style={{
        position: 'absolute',
        overflow: 'hidden',
        borderRadius: radius,
        backgroundColor: '#000',
        ...style,
      }}
    >
      <Img
        src={src}
        style={{
          position: 'absolute',
          inset: -40,
          width: 'calc(100% + 80px)',
          height: 'calc(100% + 80px)',
          objectFit: 'cover',
          filter: 'blur(40px)',
          opacity: 0.8,
        }}
      />
      <Img
        src={src}
        style={{
          position: 'absolute',
          inset: 0,
          width: '100%',
          height: '100%',
          objectFit: 'contain',
          transform: `scale(${z})`,
        }}
      />
    </div>
  );
}

export type FrameKind = 'polaroid' | 'print' | 'arch' | 'rounded' | 'circle';

/** A photo in a frame on the page, dropping in with a spring. */
export function Framed({
  src,
  len,
  kind,
  width = 860,
  height,
  tilt = 0,
  top,
  caption,
  captionStyle,
  border = '#FFFFFF',
  delay = 0,
}: {
  src: string;
  len: number;
  kind: FrameKind;
  width?: number;
  height?: number;
  tilt?: number;
  top?: number;
  caption?: ReactNode;
  captionStyle?: CSSProperties;
  border?: string;
  delay?: number;
}) {
  const f = useCurrentFrame();
  const s = useSpring(delay, 12);
  const zoom = interpolate(f, [0, len], [1, 1.08]);
  const h = height ?? (kind === 'circle' ? width : width * 1.25);
  const pad = kind === 'polaroid' ? 34 : kind === 'print' ? 22 : 0;
  const bottom = kind === 'polaroid' ? 150 : pad;
  const radius =
    kind === 'circle'
      ? '50%'
      : kind === 'arch'
        ? `${width / 2}px ${width / 2}px 18px 18px`
        : kind === 'rounded'
          ? 40
          : 10;
  return (
    <AbsoluteFill
      style={{
        alignItems: 'center',
        justifyContent: top === undefined ? 'center' : 'flex-start',
        paddingTop: top,
      }}
    >
      <div
        style={{
          position: 'relative',
          padding: `${pad}px ${pad}px ${bottom}px`,
          backgroundColor: pad ? border : 'transparent',
          borderRadius: kind === 'circle' ? '50%' : 22,
          boxShadow: '0 30px 80px rgba(0,0,0,0.20)',
          transform: `translateY(${(1 - s) * 120}px) rotate(${tilt + (1 - s) * 5}deg)`,
          opacity: Math.min(1, s * 1.5),
        }}
      >
        <div style={{ width, height: h, overflow: 'hidden', borderRadius: radius }}>
          <Img
            src={src}
            style={{
              width: '100%',
              height: '100%',
              objectFit: 'cover',
              objectPosition: '50% 40%',
              transform: `scale(${zoom})`,
            }}
          />
        </div>
        {caption && (
          <div
            style={{
              position: 'absolute',
              left: 0,
              right: 0,
              bottom: 40,
              textAlign: 'center',
              ...captionStyle,
            }}
          >
            {caption}
          </div>
        )}
      </div>
    </AbsoluteFill>
  );
}

/** Two to four photos in a grid, tiles popping in. */
export function Collage({
  srcs,
  len,
  gap = 22,
  tilt = true,
}: {
  srcs: string[];
  len: number;
  gap?: number;
  tilt?: boolean;
}) {
  const f = useCurrentFrame();
  const { fps } = useVideoConfig();
  const lift = interpolate(f, [0, len], [0, -20]);
  const cells: { x: number; y: number; w: number; h: number }[] =
    srcs.length === 2
      ? [
          { x: 90, y: 250, w: 900, h: 640 },
          { x: 90, y: 250 + 640 + gap, w: 900, h: 640 },
        ]
      : srcs.length === 3
        ? [
            { x: 90, y: 260, w: 900, h: 760 },
            { x: 90, y: 260 + 760 + gap, w: 439, h: 520 },
            { x: 90 + 439 + gap, y: 260 + 760 + gap, w: 439, h: 520 },
          ]
        : [
            { x: 90, y: 300, w: 439, h: 640 },
            { x: 90 + 439 + gap, y: 300, w: 439, h: 640 },
            { x: 90, y: 300 + 640 + gap, w: 439, h: 640 },
            { x: 90 + 439 + gap, y: 300 + 640 + gap, w: 439, h: 640 },
          ];
  return (
    <AbsoluteFill style={{ transform: `translateY(${lift}px)` }}>
      {srcs.slice(0, cells.length).map((src, i) => {
        const c = cells[i]!;
        const s = spring({ frame: f - i * 6, fps, config: { damping: 10, mass: 0.7 } });
        return (
          <div
            key={i}
            style={{
              position: 'absolute',
              left: c.x,
              top: c.y,
              width: c.w,
              height: c.h,
              borderRadius: 28,
              overflow: 'hidden',
              border: '10px solid #FFFFFF',
              boxShadow: '0 18px 40px rgba(0,0,0,0.18)',
              transform: `scale(${0.85 + 0.15 * s}) rotate(${tilt ? (i % 2 ? 2 : -2) * (1 - s * 0.5) : 0}deg)`,
              opacity: Math.min(1, s * 1.5),
            }}
          >
            <Img
              src={src}
              style={{
                width: '100%',
                height: '100%',
                objectFit: 'cover',
                objectPosition: '50% 40%',
              }}
            />
          </div>
        );
      })}
    </AbsoluteFill>
  );
}

/** Then → now: the older photo, a wipe to the newer one, then both side by side. */
export function SplitCompare({
  a,
  b,
  labelA,
  labelB,
  len,
  accent,
  ink,
  bg,
}: {
  a: string;
  b: string;
  labelA: string;
  labelB: string;
  len: number;
  accent: string;
  ink: string;
  bg: string;
}) {
  const f = useCurrentFrame();
  const wipeAt = len * 0.35;
  const sideAt = len * 0.75;
  const wipe = interpolate(f, [wipeAt, wipeAt + 24], [0, 100], {
    ...clamp,
    easing: Easing.inOut(Easing.cubic),
  });
  const side = interpolate(f, [sideAt, sideAt + 20], [0, 1], {
    ...clamp,
    easing: Easing.inOut(Easing.cubic),
  });
  const label = (text: string, show: number, left: number) => (
    <div
      style={{
        position: 'absolute',
        left,
        top: 1460,
        padding: '10px 28px',
        borderRadius: 40,
        backgroundColor: accent,
        color: '#FFFFFF',
        fontFamily: font.sans,
        fontWeight: 700,
        fontSize: 52,
        opacity: show,
      }}
    >
      {text}
    </div>
  );
  const full: CSSProperties = {
    position: 'absolute',
    top: 0,
    height: H,
    objectFit: 'cover',
    objectPosition: '50% 40%',
  };
  return (
    <AbsoluteFill style={{ backgroundColor: bg }}>
      <Img src={a} style={{ ...full, left: 0, width: W * (1 - side * 0.5), opacity: 1 }} />
      <div
        style={{
          position: 'absolute',
          top: 0,
          height: H,
          right: 0,
          width: W * (1 - side * 0.5),
          overflow: 'hidden',
          clipPath: side > 0 ? undefined : `inset(0 0 0 ${100 - wipe}%)`,
        }}
      >
        <Img src={b} style={{ ...full, left: 0, width: '100%' }} />
      </div>
      {wipe > 0 && wipe < 100 && side === 0 && (
        <div
          style={{
            position: 'absolute',
            top: 0,
            bottom: 0,
            left: `${100 - wipe}%`,
            width: 6,
            backgroundColor: accent,
          }}
        />
      )}
      {side > 0 && (
        <div
          style={{
            position: 'absolute',
            top: 0,
            bottom: 0,
            left: W / 2 - 3,
            width: 6,
            backgroundColor: bg,
          }}
        />
      )}
      {label(labelA, interpolate(f, [8, 20], [0, 1], clamp) * (wipe < 50 || side > 0 ? 1 : 0), 70)}
      {label(labelB, wipe >= 50 ? 1 : 0, side > 0 ? W / 2 + 40 : 70)}
      <div style={{ position: 'absolute', inset: 0, color: ink }} />
    </AbsoluteFill>
  );
}

// ---------- Type blocks ----------

/** A title that rises word by word (or letter by letter), with an optional big mark above. */
export function Title({
  text,
  fontFamily = font.sans,
  size = 84,
  weight = 700,
  color,
  mark,
  markColor,
  markSize = 520,
  markFont,
  sub,
  subColor,
  italic = false,
  by = 'word',
  top,
  delay = 0,
}: {
  text: string;
  fontFamily?: string;
  size?: number;
  weight?: number;
  color: string;
  mark?: string | null;
  markColor?: string;
  markSize?: number;
  markFont?: string;
  sub?: string | null;
  subColor?: string;
  italic?: boolean;
  by?: 'word' | 'letter' | 'bounce';
  top?: number;
  delay?: number;
}) {
  const f = useCurrentFrame();
  const { fps } = useVideoConfig();
  const pop = spring({ frame: f - delay, fps, config: { damping: 14, mass: 0.8 } });
  // Letters animate one by one but never break a word across lines.
  const step = by === 'word' ? 4 : 2;
  let at = 0;
  const parts = text.split(' ').map((w) => {
    const start = at;
    at += by === 'word' ? 1 : w.length + 1;
    return { w, start };
  });
  const anim = (k: number): CSSProperties => {
    const s = spring({
      frame: f - delay - k * step,
      fps,
      config: by === 'bounce' ? { damping: 8, mass: 0.6 } : { damping: 16 },
    });
    return {
      opacity: Math.min(1, s * 1.4),
      transform: `translateY(${(1 - s) * (by === 'bounce' ? 120 : 40)}px)`,
    };
  };
  return (
    <AbsoluteFill
      style={{
        alignItems: 'center',
        justifyContent: top === undefined ? 'center' : 'flex-start',
        padding: `${top ?? 0}px 90px 0`,
      }}
    >
      {mark && (
        <div
          style={{
            fontFamily: markFont ?? font.sans,
            fontWeight: 700,
            fontSize: mark.length > 2 ? markSize * 0.7 : markSize,
            lineHeight: 1,
            color: markColor ?? color,
            transform: `scale(${0.6 + 0.4 * pop})`,
          }}
        >
          {mark}
        </div>
      )}
      <div
        style={{
          fontFamily,
          fontWeight: weight,
          fontStyle: italic ? 'italic' : 'normal',
          fontSize: size,
          lineHeight: 1.25,
          color,
          textAlign: 'center',
          marginTop: mark ? 30 : 0,
        }}
      >
        {parts.map(({ w, start }, i) => (
          <span
            key={i}
            style={{
              display: 'inline-block',
              whiteSpace: 'nowrap',
              ...(by === 'word' ? anim(start) : {}),
            }}
          >
            {by === 'word'
              ? w
              : [...w].map((ch, j) => (
                  <span key={j} style={{ display: 'inline-block', ...anim(start + j) }}>
                    {ch}
                  </span>
                ))}
            {i < parts.length - 1 ? '\u00a0' : ''}
          </span>
        ))}
      </div>
      {sub && (
        <div
          style={{
            marginTop: 28,
            fontFamily: font.sans,
            fontWeight: 600,
            fontSize: 40,
            color: subColor ?? color,
            opacity: 0.65 * interpolate(f - delay, [12, 30], [0, 1], clamp),
          }}
        >
          {sub}
        </div>
      )}
    </AbsoluteFill>
  );
}

/** Text revealed a few characters a frame (letters, handwriting). */
export function TypeReveal({
  text,
  perFrame = 2,
  delay = 0,
  style,
}: {
  text: string;
  perFrame?: number;
  delay?: number;
  style: CSSProperties;
}) {
  const f = useCurrentFrame();
  const n = Math.max(0, Math.floor((f - delay) * perFrame));
  return <div style={style}>{text.slice(0, n)}</div>;
}

/** A caption over a photo, on a soft dark scrim. */
export function Caption({
  text,
  position = 'bottom',
  fontFamily = font.sans,
  size = 56,
  color = '#FFFFFF',
}: {
  text: string;
  position?: 'bottom' | 'top';
  fontFamily?: string;
  size?: number;
  color?: string;
}) {
  const f = useCurrentFrame();
  const o = interpolate(f, [6, 18], [0, 1], clamp);
  return (
    <AbsoluteFill style={{ justifyContent: position === 'bottom' ? 'flex-end' : 'flex-start' }}>
      <div
        style={{
          background: `linear-gradient(${position === 'bottom' ? '0deg' : '180deg'}, rgba(0,0,0,0.55), rgba(0,0,0,0))`,
          padding: position === 'bottom' ? '200px 90px 380px' : '260px 90px 200px',
          opacity: o,
          transform: `translateY(${(1 - o) * 20}px)`,
        }}
      >
        <div
          style={{
            fontFamily,
            fontSize: size,
            lineHeight: 1.3,
            color,
            textAlign: 'center',
            fontWeight: 600,
          }}
        >
          {text}
        </div>
      </div>
    </AbsoluteFill>
  );
}

/** "Tháng 3": a pill (or seal, or balloon tag) bottom left. */
export function AgeTag({
  label,
  bg,
  color = '#FFFFFF',
  kind = 'pill',
  bottom = 400,
}: {
  label: string | null | undefined;
  bg: string;
  color?: string;
  kind?: 'pill' | 'seal' | 'script';
  bottom?: number;
}) {
  const f = useCurrentFrame();
  const x = interpolate(f, [4, 16], [-60, 0], { ...clamp, easing: Easing.out(Easing.cubic) });
  if (!label) return null;
  const base: CSSProperties = {
    position: 'absolute',
    left: 80,
    bottom,
    transform: `translateX(${x}px)`,
    opacity: interpolate(f, [4, 16], [0, 1], clamp),
  };
  if (kind === 'seal')
    return (
      <div
        style={{
          ...base,
          width: 200,
          height: 200,
          borderRadius: 100,
          backgroundColor: bg,
          color,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          textAlign: 'center',
          fontFamily: font.serif,
          fontWeight: 600,
          fontSize: 40,
          border: '6px solid #E8B94A',
          padding: 20,
        }}
      >
        {label}
      </div>
    );
  if (kind === 'script')
    return (
      <div style={{ ...base, fontFamily: font.script, fontWeight: 600, fontSize: 72, color: bg }}>
        {label}
      </div>
    );
  return (
    <div
      style={{
        ...base,
        padding: '12px 30px',
        borderRadius: 40,
        backgroundColor: bg,
        color,
        fontFamily: font.sans,
        fontWeight: 700,
        fontSize: 56,
      }}
    >
      {label}
    </div>
  );
}

/** A piece of the art library, springing in. */
export function Art({
  name,
  style,
  delay = 0,
  spin = 0,
  float = 0,
}: {
  name: string;
  style: CSSProperties;
  delay?: number;
  spin?: number;
  float?: number;
}) {
  const f = useCurrentFrame();
  const s = useSpring(delay, 10);
  const y = float ? Math.sin((f / FPS) * 1.6) * float : 0;
  return (
    <Img
      src={art(name)}
      style={{
        position: 'absolute',
        ...style,
        transform: `${style.transform ?? ''} translateY(${y}px) scale(${s}) rotate(${(1 - s) * spin}deg)`,
        opacity: Math.min(1, s * 1.4),
      }}
    />
  );
}

// ---------- Particles ----------

/** Seeded particles: stars twinkle, confetti and petals fall, hearts float up. */
export function Particles({
  kind,
  count = 40,
  seed = 'p',
  colors,
  area = 'all',
}: {
  kind: 'stars' | 'confetti' | 'petals' | 'hearts' | 'dots';
  count?: number;
  seed?: string;
  colors: string[];
  area?: 'all' | 'edges';
}) {
  const f = useCurrentFrame();
  const t = f / FPS;
  return (
    <AbsoluteFill style={{ pointerEvents: 'none' }}>
      {Array.from({ length: count }, (_, i) => {
        let x = random(`${seed}x${i}`) * W;
        const y0 = random(`${seed}y${i}`) * H;
        if (area === 'edges' && x > 240 && x < W - 240) x = x < W / 2 ? x * 0.3 : W - (W - x) * 0.3;
        const c = colors[i % colors.length]!;
        const r = 8 + random(`${seed}r${i}`) * 16;
        const sp = 0.5 + random(`${seed}s${i}`);
        if (kind === 'stars' || kind === 'dots') {
          const tw = 0.35 + 0.65 * Math.abs(Math.sin(t * 2 * sp + i));
          return kind === 'stars' ? (
            <svg
              key={i}
              viewBox="0 0 20 20"
              style={{
                position: 'absolute',
                left: x,
                top: y0,
                width: r * 2,
                height: r * 2,
                opacity: tw,
              }}
            >
              <path
                d="M10 0 C11 7 13 9 20 10 C13 11 11 13 10 20 C9 13 7 11 0 10 C7 9 9 7 10 0Z"
                fill={c}
              />
            </svg>
          ) : (
            <div
              key={i}
              style={{
                position: 'absolute',
                left: x,
                top: y0,
                width: r * 0.8,
                height: r * 0.8,
                borderRadius: r,
                backgroundColor: c,
                opacity: tw,
              }}
            />
          );
        }
        if (kind === 'hearts') {
          const y = (y0 - t * 80 * sp + H * 2) % (H + 100);
          return (
            <svg
              key={i}
              viewBox="0 0 30 27"
              style={{
                position: 'absolute',
                left: x + Math.sin(t + i) * 20,
                top: y,
                width: r * 2.4,
                opacity: 0.7,
              }}
            >
              <path
                d="M15 27C6 20 0 15 0 8 0 3 4 0 8 0c3 0 5 2 7 4 2-2 4-4 7-4 4 0 8 3 8 8 0 7-6 12-15 19Z"
                fill={c}
              />
            </svg>
          );
        }
        const y = ((y0 + t * 220 * sp) % (H + 60)) - 30;
        const rot = t * 180 * sp + i * 40;
        return kind === 'confetti' ? (
          <div
            key={i}
            style={{
              position: 'absolute',
              left: x + Math.sin(t * 2 + i) * 30,
              top: y,
              width: r * 1.6,
              height: r * 0.7,
              borderRadius: 3,
              backgroundColor: c,
              transform: `rotate(${rot}deg)`,
            }}
          />
        ) : (
          <div
            key={i}
            style={{
              position: 'absolute',
              left: x + Math.sin(t + i) * 50,
              top: y,
              width: r * 1.4,
              height: r,
              borderRadius: '60% 0',
              backgroundColor: c,
              opacity: 0.8,
              transform: `rotate(${rot * 0.4}deg)`,
            }}
          />
        );
      })}
    </AbsoluteFill>
  );
}

/** One burst of confetti from the centre (frames from [at]). */
export function Burst({
  at = 0,
  count = 60,
  seed = 'b',
  colors,
}: {
  at?: number;
  count?: number;
  seed?: string;
  colors: string[];
}) {
  const f = useCurrentFrame() - at;
  if (f < 0 || f > 90) return null;
  return (
    <AbsoluteFill style={{ pointerEvents: 'none' }}>
      {Array.from({ length: count }, (_, i) => {
        const a = random(`${seed}a${i}`) * Math.PI * 2;
        const v = 18 + random(`${seed}v${i}`) * 26;
        const x = W / 2 + Math.cos(a) * v * f;
        const y = H * 0.42 + Math.sin(a) * v * f + 0.6 * f * f;
        return (
          <div
            key={i}
            style={{
              position: 'absolute',
              left: x,
              top: y,
              width: 22,
              height: 10,
              borderRadius: 3,
              backgroundColor: colors[i % colors.length],
              transform: `rotate(${f * 12 + i * 30}deg)`,
              opacity: interpolate(f, [60, 90], [1, 0], clamp),
            }}
          />
        );
      })}
    </AbsoluteFill>
  );
}

/** A warm light sweeping across. */
export function LightLeak({ color = '#F3C98B', len = 45 }: { color?: string; len?: number }) {
  const f = useCurrentFrame();
  const o = interpolate(f, [0, len / 2, len], [0, 0.35, 0], clamp);
  const x = interpolate(f, [0, len], [-30, 70]);
  return (
    <AbsoluteFill
      style={{
        background: `radial-gradient(circle at ${x}% 40%, ${color} 0%, transparent 55%)`,
        opacity: o,
        mixBlendMode: 'screen',
      }}
    />
  );
}

// ---------- Brand, end card, music ----------

export function BrandLogo({
  color,
  width,
  opacity = 1,
  shadow = false,
}: {
  color: string;
  width: number;
  opacity?: number;
  shadow?: boolean;
}) {
  return (
    <div
      style={{
        width,
        height: (width * keepsakeBrandSize.height) / keepsakeBrandSize.width,
        opacity,
        filter: shadow ? 'drop-shadow(0 2px 6px rgba(0,0,0,0.35))' : undefined,
      }}
      // Our own lockup from contracts, never user content.
      dangerouslySetInnerHTML={{ __html: keepsakeBrandSvg(color) }}
    />
  );
}

/** The corner mark through the video (D-068 #10), hidden on the closing scene. */
export function BrandCorner({
  brand,
  until,
  tone,
}: {
  brand: KeepsakeVideoBrand | null | undefined;
  until: number;
  tone: (frame: number) => { color: string; shadow: boolean };
}) {
  const f = useCurrentFrame();
  if (!brand?.corner) return null;
  const o = brand.opacity * interpolate(f, [15, 30, until - 15, until], [0, 1, 1, 0], clamp);
  const { color, shadow } = tone(f);
  return (
    <div style={{ position: 'absolute', right: 80, bottom: 280 }}>
      <BrandLogo color={color} width={200} opacity={o} shadow={shadow} />
    </div>
  );
}

/** The closing line, the name and the lockup. */
export function EndCard({
  closing,
  name,
  sub,
  palette,
  brand,
  closingFont = font.serif,
  closingSize = 64,
  italic = true,
  background,
  children,
}: {
  closing: string;
  name?: string;
  sub?: string | null;
  palette: StoryProps['palette'];
  brand: KeepsakeVideoBrand | null | undefined;
  closingFont?: string;
  closingSize?: number;
  italic?: boolean;
  background?: string;
  children?: ReactNode;
}) {
  const f = useCurrentFrame();
  const o = interpolate(f, [0, 15], [0, 1], clamp);
  const rise = interpolate(f, [0, FPS], [40, 0], { ...clamp, easing: Easing.out(Easing.cubic) });
  const logo = interpolate(f, [24, 40], [0, 1], clamp);
  return (
    <AbsoluteFill
      style={{
        backgroundColor: background ?? palette.background,
        alignItems: 'center',
        justifyContent: 'center',
        padding: '0 110px',
      }}
    >
      {children}
      <div
        style={{
          fontFamily: closingFont,
          fontStyle: italic ? 'italic' : 'normal',
          fontWeight: 600,
          fontSize: closingSize,
          lineHeight: 1.35,
          color: palette.ink,
          textAlign: 'center',
          opacity: o,
          transform: `translateY(${rise}px)`,
        }}
      >
        {closing}
      </div>
      {name && (
        <div
          style={{
            marginTop: 50,
            fontFamily: font.sans,
            fontWeight: 700,
            fontSize: 48,
            color: palette.accent,
            opacity: o,
          }}
        >
          {name}
        </div>
      )}
      {sub && (
        <div
          style={{
            marginTop: 12,
            fontFamily: font.sans,
            fontSize: 36,
            color: palette.ink,
            opacity: 0.6 * o,
          }}
        >
          {sub}
        </div>
      )}
      {brand?.endCard ? (
        <div style={{ position: 'absolute', bottom: 300 }}>
          <BrandLogo color={palette.ink} width={320} opacity={logo * brand.opacity} />
        </div>
      ) : null}
    </AbsoluteFill>
  );
}

export function Music({ src, total }: { src: string | null; total: number }) {
  if (!src) return null;
  return (
    <Audio
      src={src}
      volume={(f) => interpolate(f, [0, FPS, total - 1.5 * FPS, total], [0, 0.8, 0.8, 0], clamp)}
    />
  );
}

/** The photo for scene [i], cycling when there are fewer photos than scenes. */
export const photoAt = (p: StoryProps, i: number) =>
  p.photos[i % Math.max(1, p.photos.length)] ?? '';
/** The age label of photo [i] ("Tháng 3"), when known. */
export const labelAt = (p: StoryProps, i: number) => p.photoInfo?.[i]?.label ?? null;
/** The parent's lines (one per line), cycled. */
export const lineAt = (p: StoryProps, i: number) => {
  const lines = (p.lines ?? '')
    .split('\n')
    .map((l) => l.trim())
    .filter(Boolean);
  return lines.length ? lines[i % lines.length]! : '';
};
/** Photos in the order they were taken (unknown dates keep their place at the end). */
export function chronological(p: StoryProps): number[] {
  const idx = p.photos.map((_, i) => i);
  return idx.sort((a, b) => {
    const ta = p.photoInfo?.[a]?.takenAt;
    const tb = p.photoInfo?.[b]?.takenAt;
    if (ta && tb) return ta.localeCompare(tb);
    if (ta) return -1;
    if (tb) return 1;
    return a - b;
  });
}
