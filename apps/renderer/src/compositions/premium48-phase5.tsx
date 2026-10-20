import {
  AbsoluteFill,
  Audio,
  Easing,
  Img,
  interpolate,
  useCurrentFrame,
  useVideoConfig,
} from 'remotion';
import { BrandLogo, Fonts, art, clamp, font, type StoryProps } from '../kit/core';
import { fitPremiumText, premium48Frame, usePremiumFonts } from './premium48';
const ramp = (f: number, a: number, b: number) =>
  interpolate(f, [a, b], [0, 1], { ...clamp, easing: Easing.bezier(0.22, 1, 0.36, 1) });
const names = {
  paperGrain: 'p48-grain',
  wardrobeHanger: 'p48-wardrobe-hanger',
  wardrobeFabricLabel: 'p48-wardrobe-fabric-label',
  wardrobeThreadRoute: 'p48-wardrobe-thread-route',
  wardrobeStitchFrame: 'p48-wardrobe-stitch-frame',
  wardrobeMemoryBox: 'p48-wardrobe-memory-box',
  wardrobeBoxLid: 'p48-wardrobe-box-lid',
  wardrobeFoldedCloth: 'p48-wardrobe-folded-cloth',
  wardrobeButtonPair: 'p48-wardrobe-button-pair',
  wardrobeDateTab: 'p48-wardrobe-date-tab',
  wardrobeSeamDivider: 'p48-wardrobe-seam-divider',
  smileSunArc: 'p48-smile-sun-arc',
  smileSunFrame: 'p48-smile-sun-frame',
  smileSmileCurve: 'p48-smile-smile-curve',
  smileRayFan: 'p48-smile-ray-fan',
  smileQuietRing: 'p48-smile-quiet-ring',
  smileCaptionPaper: 'p48-smile-caption-paper',
  smileReactionBracket: 'p48-smile-reaction-bracket',
  smileDayTab: 'p48-smile-day-tab',
  smileSoftSpeckles: 'p48-smile-soft-speckles',
  smileClosingRays: 'p48-smile-closing-rays',
};
type Role = keyof typeof names;
export const premium48Phase5Slots = (smile: boolean, beat: number): number[] =>
  smile ? ([[0], [1], [2, 1], [1], [1]][beat] ?? []) : ([[0], [1], [2], [3, 0], [4]][beat] ?? []);
function Motif({
  p,
  role,
  x,
  y,
  w,
  h,
  opacity = 1,
  transform,
}: {
  p: StoryProps;
  role: Role;
  x: number;
  y: number;
  w: number;
  h: number;
  opacity?: number;
  transform?: string | undefined;
}) {
  return (
    <Img
      src={p.artAssets?.[role] ?? art(names[role])}
      style={{
        position: 'absolute',
        left: x,
        top: y,
        width: w,
        height: h,
        objectFit: 'fill',
        opacity,
        transform,
      }}
    />
  );
}
function Picture({
  p,
  slot,
  beat,
  x,
  y,
  w,
  h,
}: {
  p: StoryProps;
  slot: number;
  beat: number;
  x: number;
  y: number;
  w: number;
  h: number;
}) {
  const src = p.photos[slot];
  if (!src) throw new Error('premium-photo-missing');
  const crop = p.presentation?.crops[beat] ?? { x: 0, y: 0, zoom: 1, fit: 'contain' };
  return (
    <div
      style={{
        position: 'absolute',
        left: x,
        top: y,
        width: w,
        height: h,
        padding: 14,
        boxSizing: 'border-box',
        background: '#FFFCF7',
        boxShadow: '0 8px 28px #3F505918',
      }}
    >
      <div style={{ width: '100%', height: '100%', overflow: 'hidden' }}>
        <Img
          src={src}
          style={{
            width: '100%',
            height: '100%',
            objectFit: crop.fit ?? 'contain',
            objectPosition: `${(crop.x + 1) * 50}% ${(crop.y + 1) * 50}%`,
            transform: `scale(${crop.zoom})`,
            transformOrigin: `${(crop.x + 1) * 50}% ${(crop.y + 1) * 50}%`,
          }}
        />
      </div>
    </div>
  );
}
function Scene({
  p,
  beat,
  local,
  smile,
}: {
  p: StoryProps;
  beat: number;
  local: number;
  smile: boolean;
}) {
  const { width, height } = useVideoConfig(),
    story = height > 1500,
    reduced = p.presentation?.reducedMotion === true;
  const copy = p.presentation?.copy ?? {},
    slots = p.presentation?.beats[beat]?.slots ?? premium48Phase5Slots(smile, beat),
    primary = slots[0]!;
  const value = copy[p.presentation?.beats[beat]?.textKey ?? `scene${beat + 1}`] ?? '',
    show = ramp(local, 18, 32),
    open = reduced ? 1 : ramp(local, 0, 17);
  const top = smile ? (story ? 470 : 250) : story ? 272 : 220,
    ph = smile ? 620 : story ? 1010 : 600,
    captionY = story ? 1390 : 936;
  const motif = (
    role: Role,
    x: number,
    y: number,
    w: number,
    h: number,
    opacity = 1,
    transform?: string,
  ) => <Motif p={p} role={role} x={x} y={y} w={w} h={h} opacity={opacity} transform={transform} />;
  const pic = (slot: number, x: number, y: number, w: number, h: number, cropBeat = beat) => (
    <Picture p={p} slot={slot} beat={cropBeat} x={x} y={y} w={w} h={h} />
  );
  const label = (text: string, x: number, y: number, w: number, h = 64) => (
    <div
      style={{
        position: 'absolute',
        left: x,
        top: y,
        width: w,
        height: h,
        color: p.palette.ink,
        fontFamily: font.sans,
        fontSize: 28,
        lineHeight: 1.35,
        opacity: show,
        overflowWrap: 'anywhere',
      }}
    >
      {text}
    </div>
  );
  return (
    <AbsoluteFill style={{ background: p.palette.background }}>
      {motif('paperGrain', 0, 0, width, height, 0.03)}
      {!smile && (
        <>
          {motif('wardrobeHanger', 842, 115, 150, 100, 0.8)}
          <div
            style={{
              position: 'absolute',
              left: 36,
              top: top + 20,
              width: 40,
              height: ph,
              clipPath: `inset(0 0 ${reduced ? 0 : 100 * (1 - ramp(local, 0, 45))}% 0)`,
            }}
          >
            {motif('wardrobeThreadRoute', 0, 0, 40, ph, 0.7)}
          </div>
          {beat === 0 && (
            <>
              {pic(primary, 110, top + 100, 860, ph - 120)}
              {motif('wardrobeStitchFrame', 100, top + 90, 880, ph - 100)}
              <div
                style={{
                  position: 'absolute',
                  left: 130,
                  top: top - 25 + (reduced ? 0 : -10 * (1 - open)),
                  opacity: open,
                }}
              >
                {motif('wardrobeFabricLabel', 0, 0, 700, 94)}
                {label(copy.label0 ?? '', 24, 28, 650, 60)}
              </div>
            </>
          )}
          {beat === 1 && (
            <>
              {pic(primary, 110, top, 860, ph)}
              {motif('wardrobeStitchFrame', 100, top - 10, 880, ph + 20)}
              {motif('wardrobeButtonPair', 870, top + ph - 64, 130, 94)}
            </>
          )}
          {beat === 2 && (
            <>
              {pic(primary, 150, top + 40, 780, ph - 70)}
              {motif('wardrobeStitchFrame', 140, top + 30, 800, ph - 50)}
              {local < 18 && !reduced && (
                <div
                  style={{
                    position: 'absolute',
                    left: 150,
                    top: top + 40,
                    width: 780,
                    height: ph - 70,
                    clipPath: `inset(0 ${100 * open}% 0 0)`,
                  }}
                >
                  {motif('wardrobeFabricLabel', 0, 0, 780, ph - 70)}
                </div>
              )}
              {motif('wardrobeFoldedCloth', 40, top + ph - 80, 135, 96, 0.8)}
            </>
          )}
          {beat === 3 && (
            <>
              {pic(primary, 100, top + 20, 560, ph - 40)}
              {pic(slots[1]!, 710, top + ph * 0.3, 270, ph * 0.45, 0)}
              {motif('wardrobeStitchFrame', 90, top + 10, 580, ph - 20)}
              {motif('wardrobeStitchFrame', 700, top + ph * 0.3 - 10, 290, ph * 0.45 + 20)}
              {motif('wardrobeButtonPair', 728, top + ph * 0.79, 150, 108)}
            </>
          )}
          {beat === 4 && (
            <>
              {motif('wardrobeMemoryBox', 82, top - 10, 916, ph + 70)}
              {pic(primary, 130, top + 110, 820, ph - 90)}
              {motif(
                'wardrobeBoxLid',
                82,
                top - 14,
                916,
                110,
                1,
                `translateY(${reduced ? 0 : -12 * open}px)`,
              )}
              {copy.label1 && (
                <>
                  {motif('wardrobeDateTab', 96, height - 222, 800, 58)}
                  {label(copy.label1, 200, height - 210, 690, 42)}
                </>
              )}
            </>
          )}
          {beat !== 4 && motif('wardrobeSeamDivider', 96, captionY - 72, 888, 40, 0.75)}
        </>
      )}
      {smile && (
        <>
          {motif('smileSoftSpeckles', 18, top - 150, 1044, ph + 250, 0.8)}
          {beat === 0 && (
            <>
              {motif('smileQuietRing', 210, top - 65, 660, 660, 0.5)}
              {pic(primary, 130, top + 35, 820, ph - 25)}
              {motif('smileSunFrame', 120, top + 25, 840, ph - 5)}
            </>
          )}
          {(beat === 1 || beat === 3 || beat === 4) && (
            <>
              {motif(
                'smileSunArc',
                60,
                top - 125,
                960,
                360,
                beat === 1 ? (reduced ? 1 : ramp(local, 0, 18)) : 1,
                beat === 1
                  ? `scaleY(${reduced ? 1 : 0.85 + 0.15 * ramp(local, 0, 18)})`
                  : undefined,
              )}
              {pic(primary, 130, top + 65, 820, ph - 65)}
              {motif('smileSunFrame', 120, top + 55, 840, ph - 45)}
              {motif('smileSmileCurve', 300, top + ph + 24, 480, 65, 0.85)}
              {beat === 4 && motif('smileClosingRays', 856, captionY + 178, 132, 70)}
            </>
          )}
          {beat === 2 && (
            <>
              {pic(primary, 96, top + 155, 406, 300)}
              {pic(slots[1]!, 578, top + 155, 406, 300, 1)}
              {motif('smileSunFrame', 86, top + 145, 426, 320)}
              {motif('smileSunFrame', 568, top + 145, 426, 320)}
              {motif('smileReactionBracket', 514, top + ph * 0.35, 52, 190, 0.6)}
              {motif('smileRayFan', 550, top - 120, 200, 200)}
            </>
          )}
        </>
      )}
      <div
        style={{
          position: 'absolute',
          left: 96,
          top: captionY,
          width: 888,
          height: 190,
          fontFamily: font.serif,
          fontSize: fitPremiumText(value, beat === 4 ? 64 : 60, 888),
          fontWeight: 600,
          lineHeight: 1.25,
          color: p.palette.ink,
          opacity: show,
          overflowWrap: 'anywhere',
        }}
      >
        {value}
      </div>
      {beat === 4 && label(copy.signature ?? '', 96, height - 260, 800, 60)}
    </AbsoluteFill>
  );
}
export function Premium48Phase5Story(p: StoryProps & { smile?: boolean }) {
  const frame = useCurrentFrame(),
    ready = usePremiumFonts(),
    { height } = useVideoConfig(),
    { beat, local } = premium48Frame(frame),
    next = beat < 4 && local >= 198 ? ramp(local, 198, 210) : 0;
  return (
    <AbsoluteFill style={{ background: p.palette.background }}>
      <Fonts />
      {ready && <Scene p={p} beat={beat} local={local} smile={p.smile === true} />}
      {ready && next > 0 && (
        <AbsoluteFill style={{ opacity: next }}>
          <Scene p={p} beat={beat + 1} local={0} smile={p.smile === true} />
        </AbsoluteFill>
      )}
      {p.brand?.corner && beat < 4 && (
        <div style={{ position: 'absolute', left: 96, top: 80 }}>
          <BrandLogo width={190} color={p.palette.ink} opacity={p.brand.opacity} />
        </div>
      )}
      {p.brand?.endCard && beat === 4 && (
        <div style={{ position: 'absolute', left: 96, top: height - 148 }}>
          <BrandLogo
            width={260}
            color={p.palette.ink}
            opacity={p.brand.opacity * ramp(local, 18, 32)}
          />
        </div>
      )}
      {p.music && (
        <Audio
          src={p.music}
          volume={(f) => interpolate(f, [0, 12, 1014, 1049], [0, 1, 1, 0], clamp)}
        />
      )}
    </AbsoluteFill>
  );
}
