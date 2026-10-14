import {
  keepsakeBrandSize,
  keepsakeBrandSvg,
  type KeepsakeVideoBrand,
} from '@child-life/contracts';
import type { CSSProperties } from 'react';
import {
  AbsoluteFill,
  Audio,
  Easing,
  Img,
  Sequence,
  interpolate,
  spring,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
} from 'remotion';

/**
 * Video kỷ niệm (D-068; Figma MM06–MM09): 9:16, an intro with the occasion's mark and title, one
 * scene per photo (slow zoom, cross-fades), and an outro with the parents' message. Motion lives
 * here (no JSON animation engine in V1); colours, texts, photos and music come from the template
 * and the job (portal-managed, D-068 #7). The look differs per composition through [style].
 */

export interface MemoryStoryProps {
  /** Photo URLs in scene order (served to the browser by the renderer). */
  photos: string[];
  title: string;
  message: string;
  name: string;
  dateLine: string;
  /** "1", "7", "100" or null. */
  mark: string | null;
  palette: { background: string; ink: string; accent: string };
  /** URL of the track or null (Q-062). */
  music: string | null;
  durationSec: number;
  /** The Child Life logo (D-068 #10); null or missing: the plain "Child Life" line of V1. */
  brand?: KeepsakeVideoBrand | null;
  [key: string]: unknown;
}

export type StoryStyle = 'polaroid' | 'fullBleed';

export const FPS = 30;
export const INTRO = 2.5 * FPS;
export const OUTRO = 3.5 * FPS;
export const FADE = 0.5 * FPS;

const fontFace = `
@font-face { font-family: 'BVP'; font-weight: 400; src: url('${staticFile('fonts/BeVietnamPro-Regular.ttf')}'); }
@font-face { font-family: 'BVP'; font-weight: 600; src: url('${staticFile('fonts/BeVietnamPro-SemiBold.ttf')}'); }
@font-face { font-family: 'BVP'; font-weight: 700; src: url('${staticFile('fonts/BeVietnamPro-Bold.ttf')}'); }
`;
const font: CSSProperties = { fontFamily: 'BVP, sans-serif' };

/** Frames of each photo scene: what is left after the intro and outro, shared evenly. */
export function sceneFrames(durationSec: number, photos: number): number {
  const total = Math.round(durationSec * FPS);
  return Math.max(
    FPS,
    Math.floor((total - INTRO - OUTRO + FADE * (photos + 1)) / Math.max(1, photos)),
  );
}

/** The frame used as the poster (the middle of the first photo scene). */
export function posterFrame(durationSec: number, photos: number): number {
  return INTRO - FADE + Math.floor(sceneFrames(durationSec, photos) / 2);
}

function fadeInOut(frame: number, length: number): number {
  return interpolate(frame, [0, FADE, length - FADE, length], [0, 1, 1, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
}

function Intro({ p, length }: { p: MemoryStoryProps; length: number }) {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const pop = spring({ frame, fps, config: { damping: 14, mass: 0.8 } });
  const opacity = fadeInOut(frame, length);
  return (
    <AbsoluteFill
      style={{
        backgroundColor: p.palette.background,
        alignItems: 'center',
        justifyContent: 'center',
        opacity,
        ...font,
      }}
    >
      {p.mark && (
        <div
          style={{
            fontSize: p.mark.length > 2 ? 360 : 520,
            fontWeight: 700,
            lineHeight: 1,
            color: p.palette.accent,
            transform: `scale(${0.6 + 0.4 * pop})`,
          }}
        >
          {p.mark}
        </div>
      )}
      <div
        style={{
          marginTop: 40,
          padding: '0 96px',
          fontSize: 84,
          fontWeight: 700,
          lineHeight: 1.2,
          color: p.palette.ink,
          textAlign: 'center',
          transform: `translateY(${(1 - pop) * 60}px)`,
        }}
      >
        {p.title}
      </div>
      <div
        style={{ marginTop: 28, fontSize: 40, fontWeight: 600, color: p.palette.ink, opacity: 0.6 }}
      >
        {p.dateLine}
      </div>
    </AbsoluteFill>
  );
}

function Scene({
  src,
  index,
  length,
  style,
  p,
}: {
  src: string;
  index: number;
  length: number;
  style: StoryStyle;
  p: MemoryStoryProps;
}) {
  const frame = useCurrentFrame();
  const opacity = fadeInOut(frame, length);
  const zoom = interpolate(frame, [0, length], [1, 1.12], { easing: Easing.inOut(Easing.ease) });
  const drift = (index % 2 === 0 ? 1 : -1) * interpolate(frame, [0, length], [0, 30]);
  if (style === 'fullBleed') {
    return (
      <AbsoluteFill style={{ backgroundColor: '#000', opacity }}>
        <Img
          src={src}
          style={{
            width: '100%',
            height: '100%',
            objectFit: 'cover',
            transform: `scale(${zoom}) translateX(${drift}px)`,
          }}
        />
        <AbsoluteFill
          style={{ background: 'linear-gradient(transparent 62%, rgba(0,0,0,0.55))' }}
        />
        <div
          style={{
            position: 'absolute',
            left: 72,
            bottom: 120,
            color: '#fff',
            fontSize: 44,
            fontWeight: 600,
            ...font,
          }}
        >
          {p.name}
        </div>
      </AbsoluteFill>
    );
  }
  const tilt = (index % 2 === 0 ? -1 : 1) * 2.5;
  return (
    <AbsoluteFill
      style={{
        backgroundColor: p.palette.background,
        alignItems: 'center',
        justifyContent: 'center',
        opacity,
      }}
    >
      <div
        style={{
          width: 880,
          padding: '36px 36px 140px',
          backgroundColor: '#fff',
          borderRadius: 24,
          boxShadow: '0 30px 80px rgba(0,0,0,0.18)',
          transform: `rotate(${tilt}deg)`,
          position: 'relative',
        }}
      >
        <div style={{ width: 808, height: 1010, overflow: 'hidden', borderRadius: 12 }}>
          <Img
            src={src}
            style={{
              width: '100%',
              height: '100%',
              objectFit: 'cover',
              transform: `scale(${zoom}) translateX(${drift}px)`,
            }}
          />
        </div>
        <div
          style={{
            position: 'absolute',
            left: 0,
            right: 0,
            bottom: 44,
            textAlign: 'center',
            fontSize: 44,
            fontWeight: 600,
            color: p.palette.accent,
            ...font,
          }}
        >
          {p.name}
        </div>
      </div>
    </AbsoluteFill>
  );
}

/** The Child Life lockup in one colour, [width] px wide. */
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
      // The SVG is ours (contracts), never user content.
      dangerouslySetInnerHTML={{ __html: keepsakeBrandSvg(color) }}
    />
  );
}

/** Where the corner mark sits: bottom right, below the photo frames. */
export const BRAND_CORNER = { right: 80, bottom: 280, width: 200 } as const;

/**
 * The corner mark through the video (not on the closing scene, which shows the large lockup):
 * the palette's ink over flat backgrounds, white with a soft shadow over full-bleed photos.
 */
function BrandCorner({
  p,
  style,
  outroStart,
}: {
  p: MemoryStoryProps;
  style: StoryStyle;
  outroStart: number;
}) {
  const frame = useCurrentFrame();
  const brand = p.brand;
  if (!brand?.corner) return null;
  const onPhoto = style === 'fullBleed' && frame >= INTRO - FADE && frame < outroStart;
  const opacity =
    brand.opacity *
    interpolate(frame, [15, 30, outroStart - FADE, outroStart], [0, 1, 1, 0], {
      extrapolateLeft: 'clamp',
      extrapolateRight: 'clamp',
    });
  return (
    <div style={{ position: 'absolute', right: BRAND_CORNER.right, bottom: BRAND_CORNER.bottom }}>
      <BrandLogo
        color={onPhoto ? '#FFFFFF' : p.palette.ink}
        width={BRAND_CORNER.width}
        opacity={opacity}
        shadow={onPhoto}
      />
    </div>
  );
}

function Outro({ p }: { p: MemoryStoryProps }) {
  const frame = useCurrentFrame();
  const opacity = interpolate(frame, [0, FADE], [0, 1], { extrapolateRight: 'clamp' });
  const rise = interpolate(frame, [0, FPS], [40, 0], {
    extrapolateRight: 'clamp',
    easing: Easing.out(Easing.cubic),
  });
  // The lockup follows the closing line by 12 frames.
  const brandIn = interpolate(frame, [12, 12 + FADE], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  return (
    <AbsoluteFill
      style={{
        backgroundColor: p.palette.background,
        alignItems: 'center',
        justifyContent: 'center',
        padding: '0 110px',
        opacity,
        ...font,
      }}
    >
      <div
        style={{
          fontSize: 64,
          fontWeight: 600,
          lineHeight: 1.35,
          color: p.palette.ink,
          textAlign: 'center',
          transform: `translateY(${rise}px)`,
        }}
      >
        “{p.message}”
      </div>
      <div style={{ marginTop: 56, fontSize: 44, fontWeight: 700, color: p.palette.accent }}>
        {p.name}
      </div>
      <div style={{ marginTop: 12, fontSize: 36, color: p.palette.ink, opacity: 0.6 }}>
        {p.dateLine}
      </div>
      {p.brand?.endCard ? (
        <div style={{ position: 'absolute', bottom: 300 }}>
          <BrandLogo color={p.palette.ink} width={320} opacity={brandIn * p.brand.opacity} />
        </div>
      ) : (
        <div
          style={{
            position: 'absolute',
            bottom: 96,
            fontSize: 30,
            fontWeight: 600,
            color: p.palette.ink,
            opacity: 0.45,
            letterSpacing: 2,
          }}
        >
          Child Life
        </div>
      )}
    </AbsoluteFill>
  );
}

export function MemoryStory(props: MemoryStoryProps & { style: StoryStyle }) {
  const { durationInFrames } = useVideoConfig();
  const scene = sceneFrames(props.durationSec, props.photos.length);
  const outroStart = durationInFrames - OUTRO;
  return (
    <AbsoluteFill style={{ backgroundColor: props.palette.background }}>
      <style>{fontFace}</style>
      <Sequence durationInFrames={INTRO}>
        <Intro p={props} length={INTRO} />
      </Sequence>
      {props.photos.map((src, i) => (
        <Sequence key={i} from={INTRO - FADE + i * (scene - FADE)} durationInFrames={scene}>
          <Scene src={src} index={i} length={scene} style={props.style} p={props} />
        </Sequence>
      ))}
      <Sequence from={outroStart}>
        <Outro p={props} />
      </Sequence>
      <BrandCorner p={props} style={props.style} outroStart={outroStart} />
      {props.music && (
        <Audio
          src={props.music}
          volume={(f) =>
            interpolate(
              f,
              [0, FPS, durationInFrames - 1.5 * FPS, durationInFrames],
              [0, 0.8, 0.8, 0],
              {
                extrapolateLeft: 'clamp',
                extrapolateRight: 'clamp',
              },
            )
          }
        />
      )}
    </AbsoluteFill>
  );
}
